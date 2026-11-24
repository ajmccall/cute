package md.alasdair.cute.localgame.data

import android.content.Context
import dagger.Binds
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import java.io.File
import javax.inject.Qualifier
import javax.inject.Singleton
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers

@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class IoDispatcher

/** The file that holds the device's current game. */
@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class GameFile

@Module
@InstallIn(SingletonComponent::class)
abstract class GameDataModule {
    @Binds
    @Singleton
    abstract fun bindGameRepository(repository: FileGameRepository): GameRepository

    companion object {
        @Provides
        @IoDispatcher
        fun provideIoDispatcher(): CoroutineDispatcher = Dispatchers.IO

        @Provides
        @GameFile
        fun provideGameFile(@ApplicationContext context: Context): File =
            File(context.filesDir, FileGameRepository.FILE_NAME)
    }
}
