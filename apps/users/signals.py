from django.db.models.signals import post_save
from django.dispatch import receiver
from django.contrib.auth.models import User
from .models import UserProfile


@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    """创建用户时自动创建UserProfile"""
    if created:
        UserProfile.objects.create(
            user=instance,
            real_name=instance.username,  # 默认使用用户名
            user_type='student'  # 默认为学生
        )


@receiver(post_save, sender=User)
def save_user_profile(sender, instance, **kwargs):
    """保存用户时同步保存Profile"""
    if hasattr(instance, 'profile'):
        instance.profile.save()

